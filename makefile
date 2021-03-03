install:
	mkdir -p ~/.dock
	cp ./dock.sh ~/.dock/dock.sh
	sudo ln -s ~/.dock/dock.sh /usr/local/bin/dock
installforce:
	mkdir -p ~/.dock
	cp -f ./dock.sh ~/.dock/dock.sh
	sudo ln -s ~/.dock/dock.sh /usr/local/bin/dock

installdesignexample:
	cp ./dock.conf ~/.dock/dock.conf
	cp -f --recursive ./Design/ ~/.dock/
