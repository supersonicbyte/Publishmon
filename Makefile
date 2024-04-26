install:
	swift build -c release
	install .build/release/Publishmon /usr/local/bin/Publishmon
