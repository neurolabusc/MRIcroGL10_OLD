lazbuild -B ./simplelaz.lpr
if [[ "$OSTYPE" == "darwin"* ]]; then
	echo You may want to strip the executable
fi