repo = https://github.com/coshx/caravel

all: clean build

build:
	git clone $(repo) src
	cd src; jazzy \
	  --author "Coshx Labs" \
	  --author_url http://www.coshx.com/ \
	  --github_url $(repo) \
	  --root-url https://coshx.github.io/caravel/ \
	  --module-version 1.0.0 \
	  --x -project,Caravel.xcodeproj \
	  --output ../ \
	  --theme fullwidth
	rm -rf src

clean:
	rm -rf Classes* Enums* css js img docsets index.html undocumented.txt src