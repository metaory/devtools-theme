import { writeFile } from "node:fs/promises";

const [, , url, file] = process.argv;
if (!url || !file) throw new Error("usage: screenshot.mjs <ws> <png>");

const sleep = (ms) => new Promise((r) => setTimeout(r, ms));

const connect = (wsUrl) => {
  const ws = new WebSocket(wsUrl);
  const pending = new Map();
  const nextId = (
    (n = 0) =>
    () =>
      ++n
  )();

  const send = (method, params = {}) =>
    new Promise((resolve, reject) => {
      const id = nextId();
      pending.set(id, { resolve, reject });
      ws.send(JSON.stringify({ id, method, params }));
    });

  ws.addEventListener("message", ({ data }) => {
    const { id, error, result } = JSON.parse(data);
    const req = pending.get(id);
    if (!req) return;
    pending.delete(id);
    error ? req.reject(new Error(`${error.code}: ${error.message}`)) : req.resolve(result);
  });

  ws.addEventListener("close", () => {
    const err = new Error("CDP websocket closed");
    for (const { reject } of pending.values()) reject(err);
    pending.clear();
  });

  const run = async (fn) => {
    const { exceptionDetails, result } = await send("Runtime.evaluate", {
      expression: `(${fn})()`,
      returnByValue: true,
      awaitPromise: true,
    });
    if (exceptionDetails) throw new Error(exceptionDetails.exception?.description ?? "evaluate failed");
    return result?.value;
  };

  return {
    send,
    run,
    close: () => ws.close(),
    ready: new Promise((ok, err) => {
      ws.addEventListener("open", ok, { once: true });
      ws.addEventListener("error", err, { once: true });
    }),
  };
};

async function pageReady() {
  const pause = (ms) => new Promise((r) => setTimeout(r, ms));
  const frames = (n) =>
    Array.from({ length: n }).reduce((p) => p.then(() => new Promise(requestAnimationFrame)), Promise.resolve());

  const snapshot = () => {
    const { documentElement: html, body, readyState, images, fonts } = document;
    return {
      readyState,
      children: body?.children.length ?? 0,
      nodes: document.querySelectorAll("*").length,
      width: html.clientWidth,
      height: html.clientHeight,
      scroll: [html.scrollWidth, html.scrollHeight],
      images: [...images].filter((img) => !img.complete).length,
      fonts: fonts?.status,
    };
  };

  const checks = [
    (s) => s.readyState === "complete",
    (s) => s.children > 0,
    (s) => s.width > 0,
    (s) => s.height > 0,
    (s) => s.fonts !== "loading",
    (s) => s.images === 0,
  ];

  const deadline = performance.now() + 30_000;
  await document.fonts?.ready;

  const poll = async (prev = "", n = 0) => {
    const now = snapshot();
    const sig = JSON.stringify(now);
    const stable = checks.every((fn) => fn(now)) && sig === prev ? n + 1 : 0;
    if (stable >= 5) return frames(3).then(() => ({ ready: true, ...now, stable }));
    if (performance.now() >= deadline) return { ready: false, ...now, stable };
    await pause(100);
    return poll(sig, stable);
  };

  return poll();
}

function treeArrows() {
  const all = (sel, root = document) => [
    ...root.querySelectorAll(sel),
    ...[...root.querySelectorAll("*")].flatMap((el) => (el.shadowRoot ? all(sel, el.shadowRoot) : [])),
  ];
  return all(".elements-disclosure li.parent:not(.expanded)").map((li) => {
    const pad = parseFloat(getComputedStyle(li).paddingLeft) || 14;
    const { left, top, height } = li.getBoundingClientRect();
    return { x: left + pad + 5, y: top + height / 2 };
  });
}

async function showDrawer() {
  const { InspectorView, ViewManager } = await import(
    new URL("ui/legacy/legacy.js", document.querySelector("base").href).href
  );
  InspectorView.InspectorView.instance().showDrawer({
    focus: false,
    hasTargetDrawer: false,
  });
  await ViewManager.ViewManager.instance().showView("console-view");
}

async function selectApp() {
  const base = document.querySelector("base").href;
  const [{ ElementsPanel }, { ViewManager }] = await Promise.all([
    import(new URL("panels/elements/elements.js", base).href),
    import(new URL("ui/legacy/legacy.js", base).href),
  ]);
  await ViewManager.ViewManager.instance().showView("elements");
  const panel = ElementsPanel.ElementsPanel.instance();
  const pause = (ms) => new Promise((r) => setTimeout(r, ms));
  const deadline = performance.now() + 20_000;

  const rootOf = () => panel.getTreeOutlineForTesting()?.rootDOMNode;

  let root = rootOf();
  while (!root) {
    if (performance.now() >= deadline) throw new Error("elements tree has no root");
    await pause(100);
    root = rootOf();
  }

  const walk = async (node) => {
    if (node.getAttribute?.("id") === "app") return node;
    const kids = node.children() ?? (await node.getChildNodesPromise()) ?? [];
    return kids.reduce(async (found, kid) => (await found) ?? walk(kid), Promise.resolve());
  };

  let node;
  while (!(node = await walk(rootOf() ?? root))) {
    if (performance.now() >= deadline) throw new Error("no #app in elements tree");
    await pause(100);
  }
  panel.selectDOMNode(node, true);
}

const cdp = connect(url);
await cdp.ready;
await ["Page.enable", "Runtime.enable", "Page.bringToFront"].reduce(
  (p, method) => p.then(() => cdp.send(method)),
  Promise.resolve(),
);

const click = ({ x, y }, modifiers = 0) =>
  ["mousePressed", "mouseReleased"].reduce(
    (p, type) =>
      p.then(() =>
        cdp.send("Input.dispatchMouseEvent", {
          type,
          x,
          y,
          button: "left",
          clickCount: 1,
          modifiers,
        }),
      ),
    Promise.resolve(),
  );

const expand = async (n = 8) => {
  const arrows = await cdp.run(treeArrows);
  if (!arrows?.length || !n) return;
  for (const pt of arrows) await click(pt, 1);
  await sleep(50);
  return expand(n - 1);
};

const assertReady = async (label) => {
  const state = await cdp.run(pageReady);
  if (!state?.ready) throw new Error(`${label}: ${JSON.stringify(state)}`);
};

await assertReady("frontend not stable");
await cdp.run(showDrawer);
await expand();
await cdp.run(selectApp);
await assertReady("final render not stable");

const { data } = await cdp.send("Page.captureScreenshot", {
  format: "png",
  fromSurface: true,
  captureBeyondViewport: false,
});

if (!data) throw new Error("Page.captureScreenshot returned no image");

await writeFile(file, Buffer.from(data, "base64"));
cdp.close();
