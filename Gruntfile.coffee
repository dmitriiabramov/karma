deepmerge = require 'deepmerge'

# JS Hint options
JSHINT_BROWSER =
  browser: true
  strict: false
  undef: false
  camelcase: false

JSHINT_NODE =
  node: true
  strict: false

module.exports = (grunt) ->

  # Project configuration.
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    pkgFile: 'package.json'

    files:
      client: ['client/**/*.js']
      server: ['lib/**/*.js']
      grunt: ['grunt.js', 'tasks/*.js']
      scripts: ['scripts/init-dev-env.js']

    browserify:
      client:
        files:
          'static/karma.js': ['client/main.js']

    test:
      unit: 'simplemocha:unit'
      client: 'test/client/karma.conf.js'
      e2e: ['test/e2e/*/karma.conf.js', 'test/e2e/*/karma.conf.coffee', 'test/e2e/*/karma.conf.ls']

    watch:
      client:
        files: '<%= files.client %>'
        tasks: 'browserify:client'

    simplemocha:
      options:
        ui: 'bdd'
        reporter: 'dot'
      unit:
        src: [
          'test/unit/mocha-globals.coffee'
          'test/unit/**/*.coffee'
        ]

    # JSHint options
    # http://www.jshint.com/options/
    jshint:
      client:
        files:
          src: '<%= files.client %>'
        options: (deepmerge (require './node_modules/common/common/jshint-browser.json'),
          # Custom browser files configuration (override the default browser configuration file)
          JSHINT_BROWSER
        )
      server:
        files:
          src: '<%= files.server %>'
        options: (deepmerge (require './node_modules/common/common/jshint-node.json'),
          # Custom node files configuration (override the default node configuration file)
          JSHINT_NODE
        )
      grunt:
        files:
          src: '<%= files.grunt %>'
        options: (deepmerge (require './node_modules/common/common/jshint-node.json'),
          # Custom node files configuration (override the default node configuration file)
          JSHINT_NODE
        )
      scripts:
        files:
          src: '<%= files.scripts %>'
        options: (deepmerge (require './node_modules/common/common/jshint-node.json'),
          # Custom node files configuration (override the default node configuration file)
          JSHINT_NODE
        )

      options: require './node_modules/common/common/jshint.json'

    jscs:
      client: files: src: '<%= files.client %>'
      server: files: src: '<%= files.server %>'
      grunt: files: src: '<%= files.grunt %>'
      scripts: files: src: '<%= files.scripts %>'
      options:
        config: './node_modules/common/common/jscs.json'

    # CoffeeLint options
    # http://www.coffeelint.org/#options
    coffeelint:
      unittests: files: src: ['test/unit/**/*.coffee']
      taskstests: files: src: ['test/tasks/**/*.coffee']
      gruntfile: files: src: ['Gruntfile.coffee']
      options:
        configFile: './node_modules/common/common/coffeelint.json'

    'npm-publish':
      options:
        requires: ['build']
        abortIfDirty: true
        tag: ->
          minor = parseInt grunt.config('pkg.version').split('.')[1], 10
          if (minor % 2) then 'canary' else 'latest'

    'npm-contributors':
      options:
        commitMessage: 'chore: update contributors'

    bump:
      options:
        updateConfigs: ['pkg']
        commitFiles: ['package.json', 'CHANGELOG.md']
        commitMessage: 'chore: release v%VERSION%'
        push: false,
        # A crazy hack.
        # TODO(vojta): fix grunt-bump
        gitDescribeOptions: '| echo "beta-$(git rev-parse --short HEAD)"'


  grunt.loadTasks 'tasks'
  # Load grunt tasks automatically
  require('load-grunt-tasks') grunt

  grunt.registerTask 'build', ['browserify:client']
  grunt.registerTask 'default', ['build', 'test', 'lint']
  grunt.registerTask 'lint', ['jshint', 'jscs', 'coffeelint']
  grunt.registerTask 'release', 'Build, bump and publish to NPM.', (type) ->
    grunt.task.run [
      'npm-contributors'
      "bump:#{type||'patch'}:bump-only"
      'build'
      'changelog'
      'bump-commit'
      'npm-publish'
    ]
