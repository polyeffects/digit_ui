

PYTHON_VERSION := $(shell cat .python-version)

# Install the project's dependencies
.PHONY: install
install: install-venv install-serd

.PHONY: install-venv
install-venv:
	pipenv --python ${PYTHON_VERSION} --site-packages
	pipenv install --dev

# https://github.com/drobilla/serd/blob/master/INSTALL.md
.PHONY: serd
serd: find-site-packages-path
	@echo "${USER_SITE_PACKAGES_PATH}"

	git clone git@github.com:drobilla/serd.git build/serd
	cd build/serd
	pipenv run meson setup build/serd build/serd/build
	pipenv run meson configure build/serd/build --no-pager
	pipenv run bash -c 'cd build/serd/build && meson compile'
	pipenv run bash -c 'cd build/serd/build && meson install --destdir=${USER_SITE_PACKAGES_PATH}'


# Run the project
.PHONY: run
run:
	pipenv run python show_widget.py -platform eglfs -style ./poly_style/

# Clean up unused packages
.PHONY: clean
clean:
	pipenv clean
	pipenv --rm
	rm -rf build/

	mkdir -p build
	touch build/.gitkeep

.PHONY: find-site-packages-path
find-site-packages-path:
	$(eval USER_SITE_PACKAGES_PATH:=$(shell pipenv run python -m site --user-site))

.PHONY: sp
sp: find-site-packages-path
	echo ${USER_SITE_PACKAGES_PATH}


	

