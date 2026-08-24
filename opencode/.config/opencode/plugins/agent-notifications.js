export const AgentNotifications = async ({ $, directory }) => ({
  event: async ({ event }) => {
    if (event.type === "permission.asked") {
      await $`agent-notify opencode input-required ${directory} Permission requested`
    }
    if (event.type === "session.idle") {
      await $`agent-notify opencode completed ${directory}`
    }
  },
})
