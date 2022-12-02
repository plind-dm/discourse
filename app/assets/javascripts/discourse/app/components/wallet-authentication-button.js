import Component from "@ember/component";
import { action } from "@ember/object";
import loadScript from "discourse/lib/load-script";
import Group from "discourse/models/group";
import discourseComputed from "discourse-common/utils/decorators";

const UNLOCK_URL = "https://unlock.radiant.capital/unlock.latest.min.js";

export default Component.extend({
  tagName: "",
  label: "topic.create",
  btnClass: "btn-default",

  init() {
    let returnValue = false;
    Group.findAll().then((groups) => {
      const _availableGroups = groups.filterBy("automatic", false);
      _availableGroups.forEach((group) => {
        if (group.name === "rfp-author" || group.name === "rfp-commenter") {
          // eslint-disable-next-line no-console
          console.log("_available groups", _availableGroups);
          returnValue = true;
          this._isWalletAuthenticated = true;
        }
      });
    });

  }

  @action
  onAuthenticate() {
    loadScript(UNLOCK_URL).then(() => {
      window.unlockProtocol.loadCheckoutModal();
    });
  },
});
