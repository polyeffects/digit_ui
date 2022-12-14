
# Install the project's dependencies
.PHONY: install
install:
	pipenv install --dev

# Run the project
.PHONY: run
run:
	pipenv run python show_widget.py -platform eglfs -style ./poly_style/

# Clean up unused packages
.PHONY: clean
clean:
	pipenv clean
