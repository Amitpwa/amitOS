savedcmd_amitfs.mod := printf '%s\n'   amitfs.o | awk '!x[$$0]++ { print("./"$$0) }' > amitfs.mod
