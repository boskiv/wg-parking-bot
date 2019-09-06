# wg-parking-bot
Telegram bot to rotate parking keys between members

# Logic
- Register member (`/register`)
- Handle absence (`/skip`)
- Handle last month winners (`/info`)
- Rotate keys between uniq members (`/shuffle`) (only admin can do it manually)
- Schedule rotation monthly

# Admin logic
- Handle admin commands ENV['ADMIN_LIST']
- Manage keys count (`/keys`)
- Reset state (`/reset`)

# Todo
- Fair uniq logic (weight based for example)
- Simple algorithm distribution stats

# Flow
Last day of month bot run a task to decide a winners.
Make a winners table and print it into channel. (It can be private message or public channel)
If participant want to skip a round he must send `/skip` command to bot.


