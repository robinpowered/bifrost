var path = require('path');

(function() {
  module.exports = function(grunt) {
    'use strict';
    var path, _;
    _ = grunt.util._;
    path = require('path');
    grunt.initConfig({
      pkg: grunt.file.readJSON('package.json'),
      coffeelint: {
        lib: {
          src: ['*.coffee', 'lib/**/*.coffee'],
        },
        options: {
          no_trailing_whitespace: {
            level: 'error'
          },
          max_line_length: {
            level: 'ignore'
          }
        }
      },
      coffee: {
        all: {
          expand: true,
          cwd: './',
          src: ['*.coffee', 'lib/**/*.coffee'],
          dest: path.resolve(__dirname, 'dist'),
          ext: '.js'
        },
      },
      copy: {
        all: {
          files: [
            {
              src: 'package.json',
              dest: 'dist/'
            },
            {
              src: 'config.json',
              dest: 'dist/'
            },
            {
              src: 'rbn-pi.js',
              dest: 'dist/'
            },
            {
              src: 'start.sh',
              dest: 'dist/'
            },
            {
              src: 'cron/**',
              dest: 'dist/'
            }
          ]
        }
      },
      clean: ['out/'],
      rsync: {
        pi: {
          files: 'dist/',
          options: {
            host: "",
            user: "pi",
            remoteBase: "/home/pi/bifrost"
          }
        }
      }
    });
    grunt.loadNpmTasks('grunt-coffeelint');
    grunt.loadNpmTasks('grunt-contrib-coffee');
    grunt.loadNpmTasks('grunt-contrib-clean');
    grunt.loadNpmTasks('grunt-contrib-copy');
    grunt.loadNpmTasks('grunt-rsync-2');
    grunt.registerTask('lint', ['coffeelint']);
    grunt.registerTask('compile', [
      'coffeelint',
      'coffee',
      'copy']
      );
    grunt.registerTask('rsync_pi', 'rsync code to the raspberry pi', function (n) {
      var hostArr, hosts;
      hosts = grunt.option('hosts');
      if (hosts === undefined) {
        console.log("*** Submit this with the '--hosts' option, \
          which is a comma separated list of base station hostnames or \
          ip addresses ***");
        return false;
      }
      else {
        hostArr = hosts.split(",")
        for (var i in hostArr) {
          var host = hostArr[i];
          grunt.config.set('rsync.pi.options.host', host);
          grunt.task.run(['rsync:pi']);
        }
      }

      // 'rsync:pi'
    });
    var defaultTasks = ['compile'];
    grunt.registerTask('default', defaultTasks);
    return grunt.registerTask('pi', ['compile', 'rsync_pi']);
  };

}).call(this);
