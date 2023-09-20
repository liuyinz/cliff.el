# Changelog

## [0.1.0](https://github.com/liuyinz/git-cliff.el/compare/v0.1.0..v0.1.0) - 2023-09-17

### Bug Fixes

- **(config)** update config var when add config file in repo - ([aecdda0](https://github.com/liuyinz/git-cliff.el/commit/aecdda075f01c83f9355edf6c742647aeee882d0))
- **(preview)** erase content before preview new output - ([b9e4b9d](https://github.com/liuyinz/git-cliff.el/commit/b9e4b9dcf4459ae117e62a83ac9ec04f78b40f08))
- get text property wrongly from completing-read return value - ([ed10163](https://github.com/liuyinz/git-cliff.el/commit/ed101632e6e3045c3a08287834762a26ffb487fe))
- git-cliff--choose-template comletion sorting error - ([9c7c0dd](https://github.com/liuyinz/git-cliff.el/commit/9c7c0dde61867c66efefb9458056fe331e4a1826))
- git-cliff--configs return wrong value - ([67dd663](https://github.com/liuyinz/git-cliff.el/commit/67dd6635ff4ea7a877deaf0d26dfbf7d778d2976))
- do not set prepending as init state - ([873b8b8](https://github.com/liuyinz/git-cliff.el/commit/873b8b88e6c7705562fef7ea5719472321cd7b1c))
- use repo dir instead of workdir as default-directory - ([67adf63](https://github.com/liuyinz/git-cliff.el/commit/67adf63e4bc2ea37e6adbbe8e1ae310ff6e49d03))
- IO error path not found when args string contain --<option>=~ - ([14ca85a](https://github.com/liuyinz/git-cliff.el/commit/14ca85ac4ffa464824b006f4b6e54b1bc99d888e))
- use defconst to define git-cliff-config-regexp - ([7acca02](https://github.com/liuyinz/git-cliff.el/commit/7acca02b7fc93bdf242822748ee56953680d8ac7))
- set correct name for shell-command-buffer - ([82d9da2](https://github.com/liuyinz/git-cliff.el/commit/82d9da28793b8adc4fa288d8c9c671fff48658ad))
- switch to target buffer after call git-cliff--run - ([84bca0f](https://github.com/liuyinz/git-cliff.el/commit/84bca0f63629dfaef744648ef449b325415d91ba))

### Documentation

- **(README)** update todo list - ([88532ae](https://github.com/liuyinz/git-cliff.el/commit/88532ae8ded2151e6acb0c9012ce3df3302fa3f1))
- add README.md - ([f94fd7c](https://github.com/liuyinz/git-cliff.el/commit/f94fd7c6bed4a9dcc2d2baa2def1a130991d7a85))

### Features

- **(menu)** provide repo infomations in transient menu - ([04231e8](https://github.com/liuyinz/git-cliff.el/commit/04231e888ac20343a7fd05fce12e57aee075b3c5))
- **(preset)** add configs from git-cliff/examples - ([2bf85c3](https://github.com/liuyinz/git-cliff.el/commit/2bf85c30f347282bb949f9114f7174c04a585fd8))
- **(transient)** add git-cliff-menu - ([fa6e0c5](https://github.com/liuyinz/git-cliff.el/commit/fa6e0c5b313b4b6deeaa00fef10082eb2927505e))
- add related suffixes - ([1fd8383](https://github.com/liuyinz/git-cliff.el/commit/1fd83835b0911bfb94729fd03aeddd3725e6a614))
- set default value for changelog reader - ([db5fccc](https://github.com/liuyinz/git-cliff.el/commit/db5fccc058ea6b7a0bc3b8b44080a30dcdcc79d2))
- add option --repository - ([fdf80bb](https://github.com/liuyinz/git-cliff.el/commit/fdf80bba880e2076db00d9c6ef8a034402fe0596))
- extract body templates to directory examples - ([408b0a5](https://github.com/liuyinz/git-cliff.el/commit/408b0a5240fa83f8911b6a346d213d710ba1413c))
- support --body option - ([73a4ee6](https://github.com/liuyinz/git-cliff.el/commit/73a4ee609c0e1d13db1a1eb307f6219cab5a5b27))

### Miscellaneous Chores

- **(changelog)** update cliff config - ([61d2c0a](https://github.com/liuyinz/git-cliff.el/commit/61d2c0a8c8c9761e6eb7eef1f0a6a4ca4a144925))
- **(ci)** update actions/checkout - ([e1d025f](https://github.com/liuyinz/git-cliff.el/commit/e1d025f2a7b1d5382388264615e66c9608848583))
- **(gitignore)** ignore autoloads and tmp file - ([c0b7ad5](https://github.com/liuyinz/git-cliff.el/commit/c0b7ad52f9811868e35e39b305416554bc554069))
- **(init)** initial commit - ([a75fcaa](https://github.com/liuyinz/git-cliff.el/commit/a75fcaa17e2983e3abce406da7415f9c4075378f))
- add cliff.toml for generate changelog - ([003ca8e](https://github.com/liuyinz/git-cliff.el/commit/003ca8e88c34c6b0ae4b79eab947a506ceed7146))

<!-- generated by git-cliff -->