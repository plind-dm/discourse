import { test } from "qunit";
import I18n from "I18n";
import sinon from "sinon";
import { click, visit } from "@ember/test-helpers";
import {
  acceptance,
  exists,
  query,
} from "discourse/tests/helpers/qunit-helpers";
import DiscourseURL from "discourse/lib/url";
import { fixturesByUrl } from "discourse/tests/helpers/create-pretender";
import { cloneJSON } from "discourse-common/lib/object";

acceptance("User Preferences - Account", function (needs) {
  needs.user();

  let customUserProps = {};
  let pickAvatarRequestData = null;
  let gravatarUploadId = 123456789;

  needs.pretender((server, helper) => {
    server.get("/u/eviltrout.json", () => {
      const json = cloneJSON(fixturesByUrl["/u/eviltrout.json"]);
      json.user.can_edit = true;

      for (const [key, value] of Object.entries(customUserProps)) {
        json.user[key] = value;
      }

      return helper.response(json);
    });

    server.delete("/u/eviltrout.json", () =>
      helper.response({ success: true })
    );

    server.post("/u/eviltrout/preferences/revoke-account", () => {
      return helper.response({
        success: true,
      });
    });

    server.put("/u/eviltrout/preferences/avatar/pick", (request) => {
      pickAvatarRequestData = helper.parsePostData(request.requestBody);
      return helper.response({ success: true });
    });

    server.post("/user_avatar/eviltrout/refresh_gravatar.json", () => {
      return helper.response({
        gravatar_upload_id: gravatarUploadId,
        gravatar_avatar_template: "/images/gravatar_is_not_avatar.png",
      });
    });
  });

  needs.hooks.afterEach(() => {
    customUserProps = {};
    pickAvatarRequestData = null;
  });

  test("Delete dialog", async function (assert) {
    sinon.stub(DiscourseURL, "redirectAbsolute");

    customUserProps = {
      can_delete_account: true,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".delete-account .btn-danger");
    await click(".dialog-footer .btn-danger");

    assert.strictEqual(
      query(".dialog-body").textContent.trim(),
      I18n.t("user.deleted_yourself"),
      "confirmation dialog is shown"
    );

    await click(".dialog-footer .btn-primary");

    assert.ok(
      DiscourseURL.redirectAbsolute.calledWith("/"),
      "redirects to home after deleting"
    );
  });

  test("connected accounts", async function (assert) {
    await visit("/u/eviltrout/preferences/account");

    assert.ok(
      exists(".pref-associated-accounts"),
      "it has the connected accounts section"
    );

    assert.ok(
      query(
        ".pref-associated-accounts table tr:nth-of-type(1) td:nth-of-type(1)"
      ).innerHTML.includes("Facebook"),
      "it lists facebook"
    );

    await click(
      ".pref-associated-accounts table tr:nth-of-type(1) td:last-child button"
    );

    assert.ok(
      query(
        ".pref-associated-accounts table tr:nth-of-type(1) td:last-of-type"
      ).innerHTML.includes("Connect")
    );
  });

  test("avatars are selectable for staff user when `selectable_avatars_mode` site setting is set to `staff`", async function (assert) {
    this.siteSettings.selectable_avatars_mode = "staff";

    customUserProps = {
      moderator: true,
      admin: false,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(
      exists(".selectable-avatars"),
      "opens the avatar selection modal"
    );

    assert.ok(
      exists("#uploaded-avatar"),
      "avatar selection modal includes option to upload"
    );
  });

  test("avatars are not selectable for non-staff user when `selectable_avatars_mode` site setting is set to `staff`", async function (assert) {
    this.siteSettings.selectable_avatars_mode = "staff";

    customUserProps = {
      moderator: false,
      admin: false,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(
      exists(".selectable-avatars"),
      "opens the avatar selection modal"
    );

    assert.notOk(
      exists("#uploaded-avatar"),
      "avatar selection modal does not include option to upload"
    );
  });

  test("avatars not selectable when `selectable_avatars_mode` site setting is set to `no_one`", async function (assert) {
    this.siteSettings.selectable_avatars_mode = "no_one";

    customUserProps = {
      admin: true,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(
      exists(".selectable-avatars"),
      "opens the avatar selection modal"
    );

    assert.notOk(
      exists("#uploaded-avatar"),
      "avatar selection modal does not include option to upload"
    );
  });

  test("avatars are selectable for user with required trust level when `selectable_avatars_mode` site setting is set to `tl3`", async function (assert) {
    this.siteSettings.selectable_avatars_mode = "tl3";

    customUserProps = {
      trust_level: 3,
      moderator: false,
      admin: false,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(
      exists(".selectable-avatars"),
      "opens the avatar selection modal"
    );

    assert.ok(
      exists("#uploaded-avatar"),
      "avatar selection modal includes option to upload"
    );
  });

  test("avatars are not selectable for user without required trust level when `selectable_avatars_mode` site setting is set to `tl3`", async function (assert) {
    this.siteSettings.selectable_avatars_mode = "tl3";

    customUserProps = {
      trust_level: 2,
      moderator: false,
      admin: false,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(
      exists(".selectable-avatars"),
      "opens the avatar selection modal"
    );

    assert.notOk(
      exists("#uploaded-avatar"),
      "avatar selection modal does not include option to upload"
    );
  });

  test("avatars are selectable for staff user when `selectable_avatars_mode` site setting is set to `tl3`", async function (assert) {
    this.siteSettings.selectable_avatars_mode = "tl3";

    customUserProps = {
      trust_level: 2,
      moderator: true,
      admin: false,
    };

    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(
      exists(".selectable-avatars"),
      "opens the avatar selection modal"
    );

    assert.ok(
      exists("#uploaded-avatar"),
      "avatar selection modal includes option to upload"
    );
  });

  test("default avatar selector", async function (assert) {
    await visit("/u/eviltrout/preferences/account");
    await click(".pref-avatar .btn");

    assert.ok(exists(".avatar-choice"), "opens the avatar selection modal");

    await click(".avatar-selector-refresh-gravatar");

    assert.ok(
      exists(".avatar[src='/images/gravatar_is_not_avatar.png']"),
      "displays the new gravatar image"
    );

    await click("#gravatar");
    await click(".modal-footer .btn");

    assert.deepEqual(
      pickAvatarRequestData,
      {
        type: "gravatar",
        upload_id: `${gravatarUploadId}`,
      },
      "includes the right pick avatar request params"
    );
  });
});
