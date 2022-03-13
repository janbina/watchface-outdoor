sdk := ~/.Garmin/ConnectIQ/Sdks/connectiq-sdk-lin-4.0.5-2021-08-09-29788b0dc/bin
out := ./bin/outdoor.prg
key := ~/developer_key.der
device := venu2

all: build run

build:
	$(sdk)/monkeyc -d $(device) -f ./monkey.jungle -o $(out) -y $(key)

run:
	$(sdk)/connectiq &
	$(sdk)/monkeydo bin/outdoor.prg $(device)
