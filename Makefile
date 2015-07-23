remake: clean all

all: rhevm-syslog.pdf

clean:
	rm -f rhevm-syslog.pdf
	
%.pdf: %.md
	pandoc $^ -o $@
