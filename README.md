# Zig Version Switcher
A simple Linux zig version switcher

## Usage
    zvs help           	print this message
    zvs fetch          	fetch the latest index.json
    zvs current        	print current version
    zvs installable    	list installable version
    zvs installed      	list installed version
    zvs remove VERSION 	remove VERSION
    zvs purge          	remove all version except the current one
    zvs VERSION        	install VERSION

## Install
```sh
git clone https://github.com/Ogromny/zvs.sh $HOME/.zvs
cd $HOME/.zvs
chmod +x zvs.sh
./zvs.sh fetch
./zvs.sh master # or any version listed in `zvs installable`
echo "export PATH=\"$PATH:$HOME/.zvs/current\"" > $HOME/.profile"
```

## Uninstall
```sh
rm -r $HOME/.zvs
# Don't forget to remove the PATH in your `.profile` or whatever
```

## Note
    This was only tested on linux, but should also works on FreeBSD, maybe MacOS too.
    Windows support are not planned.
    Don't forget to run `zvs.sh fetch` to update to the latest `index.json`
