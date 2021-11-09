all: install


rebuild: clean install

fetch:
	# download source update
	@(PYENV_VERSION=ve python ${HOME}/.cheat.sh/lib/fetch.py fetch-all)

install:
	# install server
	@(PYENV_VERSION=ve pip install -r requirements.txt)

run:
	# run server
	@(PYENV_VERSION=ve PYTHONIOENCODING=UTF-8 python ${HOME}/.cheat.sh/bin/srv.py)

clean:
	# clean redis server
	@(redis-cli keys \*| grep -e cheat -e tldr -e learnxiny | xargs redis-bash-cli del)
