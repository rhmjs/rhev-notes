remake: clean all

all: rhevm-syslog.pdf

clean:
	rm -f rhevm-syslog.pdf
	
git-ready:
	@${MAKE} clean
	@${MAKE} all
	@${MAKE} clean
	git status	
	
%.pdf: %.md
	pandoc $^ -o $@
