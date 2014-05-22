Rbn-pi Cron File
===

`rbn-pi-reboot` is a cron file that will be copied into `/etc/cron.d` by the raspberry pi install script.

It's set to run `app.js`, located in the top level of this repo, using `forever` on a reboot of the pi.
