#!/usr/bin/python3


from subprocess import check_output


rsp = check_output(["/usr/lib/update-notifier/apt-check", "--human-readable"])
rsp = rsp.decode("utf-8")
pckges_to_update = rsp.split("\n")[0]

with open("/home/juan/.check_updates_status", "w") as f:
    f.write(pckges_to_update)
