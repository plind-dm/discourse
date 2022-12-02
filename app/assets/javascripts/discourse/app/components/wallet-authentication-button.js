import Component from "@ember/component";
import { action } from "@ember/object";
import loadScript from "discourse/lib/load-script";
import Group from "discourse/models/group";

const UNLOCK_URL = "https://unlock.radiant.capital/unlock.latest.min.js";

export default Component.extend({
  tagName: "",
  label: "topic.create",
  btnClass: "btn-default",
  isWalletAuthenticated: false,
  init() {
    Group.findAll().then((groups) => {
      const _availableGroups = groups.filterBy("automatic", false);
      _availableGroups.forEach((group) => {
        if (group.name === "rfp-author" || group.name === "rfp-commenter") {
          // eslint-disable-next-line no-console
          console.log("_available groups", _availableGroups);
          this.set("isWalletAuthenticated", true);
        }
      });
    });
  },

  @action
  onAuthenticate() {
    loadScript(UNLOCK_URL).then(() => {
      window.unlockProtocol.loadCheckoutModal();
    });
  },
});
