# Publishmon

Swifty deamon which watches for file changes, regenerates content and restarts http server for you Publish website.

  

We all love Publish [], but re-running the `publish run` in the terminal every time we make a change to our source files can become tiring.

Pubishmon does that automatically for you! It watches for file changes inside your website's source files and re-runs `publish run` for you.

  

# Installation

To install publishmon simply run `make` within a local copy of the Publishmon repo:

```
$ git clone https://github.com/supersonicbyte/Publishmon.git

$ cd Publishmon

$ make
```

# Usage

After intallation to run Publishmon simply run `publishmon` in your terminal within an directory which contains your website's Publish Swift Package.

```
$ publishmon
```

# Contributions and support

Publishmon is an open-source project and contributions are welcomed.
