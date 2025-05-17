import { describe, expect, it } from 'vitest'
import { ensureImportSemicolons } from '../src/core/style-compiler'

describe('ensureImportSemicolons', () => {
	it('should add semicolons to @import statements that do not have them', () => {
		const input = `@import url("style1.css")
@import url("style2.css");
@import "style3.css"
@import "style4.css";`

		const expected = `@import url("style1.css");
@import url("style2.css");
@import "style3.css";
@import "style4.css";`

		expect(ensureImportSemicolons(input)).toEqual(expected)
	})

	it('should not modify @import statements that already have semicolons', () => {
		const input = `@import url("style1.css");
@import "style2.css";`

		expect(ensureImportSemicolons(input)).toEqual(input)
	})

	it('should handle @import statements with comments', () => {
		const input = `/* Comment */
@import url("style1.css") /* inline comment */
@import "style2.css"; /* another comment */`

		const expected = `/* Comment */
@import url("style1.css") /* inline comment */;
@import "style2.css"; /* another comment */`

		expect(ensureImportSemicolons(input)).toEqual(expected)
	})

	it('should handle complex CSS with multiple @import statements', () => {
		const input = `/* Header styles */
@import url("header.css")

body {
  margin: 0;
  padding: 0;
}

@import "footer.css"

.container {
  max-width: 1200px;
}`

		const expected = `/* Header styles */
@import url("header.css");

body {
  margin: 0;
  padding: 0;
}

@import "footer.css";

.container {
  max-width: 1200px;
}`

		expect(ensureImportSemicolons(input)).toEqual(expected)
	})

	it('should return the original CSS if there are no @import statements', () => {
		const input = `body {
  margin: 0;
  padding: 0;
}

.container {
  max-width: 1200px;
}`

		expect(ensureImportSemicolons(input)).toEqual(input)
	})

	it('should handle empty input', () => {
		expect(ensureImportSemicolons('')).toEqual('')
	})
})
