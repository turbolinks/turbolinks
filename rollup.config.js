import typescript from "rollup-plugin-typescript2"
import { version } from "./package.json"
const year = new Date().getFullYear()

const options = {
  plugins: [
    typescript({
      cacheRoot: "node_modules/.cache",
      tsconfigDefaults: {
        compilerOptions: {
          removeComments: true
        }
      }
    })
  ],
  watch: {
    include: "src/**"
  }
}

export default [
  {
    input: "src/index.ts",
    output: {
      banner: `/*\nTurbolinks ${version}\nCopyright © ${year} Basecamp, LLC\n */`,
      file: "dist/turbolinks.js",
      format: "umd",
      name: "Turbolinks",
      sourcemap: true
    },
    ...options
  },

  {
    input: "src/tests/index.ts",
    output: {
      file: "dist/tests.js",
      format: "cjs",
      sourcemap: true
    },
    external: [
      "intern"
    ],
    ...options
  }
]
