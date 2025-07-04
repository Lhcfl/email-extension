import { apiInitializer } from "discourse/lib/api";
import ReplyViaEmail from "../discourse/components/reply-via-email";

export default apiInitializer("1.16.0", (api) => {
  api.addTrackedPostProperties("can_reply_via_email");

  api.registerValueTransformer(
    "post-menu-buttons",
    ({ value: dag, context: { firstButtonKey, lastHiddenButtonKey } }) => {
      if (
        !api.container.lookup("service:site-settings")
          .email_extension_reply_by_email_address
      ) {
        return;
      }
      dag.add(
        "reply-via-email",
        ReplyViaEmail,
        api.getCurrentUser()
          ? {
              before: lastHiddenButtonKey,
            }
          : {
              after: firstButtonKey,
            }
      );
    }
  );
});
