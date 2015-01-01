GEN=OscilloscopeMsg.java TimeMsg.java

all: oscilloscope.jar

oscilloscope.jar: Oscilloscope.class
	jar cf $@ *.class

OscilloscopeMsg.java: SenseMote.h
	mig -target=null -java-classname=OscilloscopeMsg java SenseMote.h RADIO_MSG -o $@

TimeMsg.java: SenseMote.h
	mig -target=null -java-classname=TimeMsg java SenseMote.h TIME_MSG -o $@

Oscilloscope.class: $(wildcard *.java) $(GEN)
	javac *.java

clean:
	rm -f *.class $(GEN)

veryclean: clean
	rm oscilloscope.jar
