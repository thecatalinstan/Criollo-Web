import { babel } from '@rollup/plugin-babel'
import { terser } from "rollup-plugin-terser";

export default {
  output: {
    name: 'criollo_web',
    format: 'iife'
  },
  plugins: [
    babel({
      babelHelpers: 'bundled' ,
      exclude: 'node_modules/**',
      presets: ['@babel/preset-env'],
      babelrc: false
    }),
    terser()
  ]
}
