# wg-parking-bot
Telegram bot to rotate parking keys between members

# Logic
- Register member (`/register`)
- Handle absense (`/skip`)
- Handle last month winners
- Rotate keys between uniq members

# Admin logic
- Handle admin commands
- Manage keys count (`/keys`)
- Reset state (`/reset`)
- Uniq logic

# Flow
Last day of month bot run a task to decide a winners.
Make a winners table and print it into channel. (It can be private message or public channel)
If participant want to skip a round he must send `/skip` command to bot.


