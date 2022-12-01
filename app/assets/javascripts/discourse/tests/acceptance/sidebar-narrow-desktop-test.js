import { test } from "qunit";

import { click, settled, visit, waitUntil } from "@ember/test-helpers";

import { acceptance, exists } from "discourse/tests/helpers/qunit-helpers";

acceptance("Sidebar - Narrow Desktop", function (needs) {
  needs.user();

  needs.settings({
    enable_experimental_sidebar_hamburger: true,
    enable_sidebar: true,
  });

  test("wide sidebar is changed to cloak when resize to narrow screen", async function (assert) {
    await visit("/");
    await settled();
    assert.ok(exists("#d-sidebar"), "wide sidebar is displayed");

    await click(".header-sidebar-toggle .btn");

    assert.ok(!exists("#d-sidebar"), "widge sidebar is collapsed");

    await click(".header-sidebar-toggle .btn");

    assert.ok(exists("#d-sidebar"), "wide sidebar is displayed");

    const bodyElement = document.querySelector("body");
    bodyElement.style.width = "990px";

    await waitUntil(
      () => document.querySelector(".btn-sidebar-toggle.narrow-desktop"),
      {
        timeout: 5000,
      }
    );
    await click(".btn-sidebar-toggle");

    assert.ok(
      exists(".sidebar-hamburger-dropdown"),
      "cloak sidebar is displayed"
    );

    await click("#main-outlet");
    assert.ok(
      !exists(".sidebar-hamburger-dropdown"),
      "cloak sidebar is collapsed"
    );

    bodyElement.style.width = "1200px";
    await waitUntil(() => document.querySelector("#d-sidebar"), {
      timeout: 5000,
    });
    assert.ok(exists("#d-sidebar"), "wide sidebar is displayed");

    bodyElement.style.width = null;
  });
});
