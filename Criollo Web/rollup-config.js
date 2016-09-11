import babel from 'rollup-plugin-babel'
import json from 'rollup-plugin-json'
import commonjs from 'rollup-plugin-commonjs'
import nodeResolve from 'rollup-plugin-node-resolve'
import uglify from 'rollup-plugin-uglify'

export default {
  moduleName: 'criollo-web',
  plugins: [
    json(),
    nodeResolve(),
    commonjs(),
    babel({
      exclude: 'node_modules/**',
      presets: [
        [
          "es2015",
          {
            "modules": false
          }
        ]
      ],
      "plugins": [
        "external-helpers"
      ],
      babelrc: false
    }),
    uglify()
  ]
}
