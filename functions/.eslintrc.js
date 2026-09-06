module.exports = {
    env: {
        es6: true,
        node: true,
    },
    parserOptions: {
    // Node 22 (see package.json engines). The template shipped 2018, which
    // could not parse the optional chaining and spread this codebase uses.
        ecmaVersion: 2022,
        sourceType: "script",
    },
    extends: [
        "eslint:recommended",
        "google",
    ],
    rules: {
        "no-restricted-globals": ["error", "name", "length"],
        "prefer-arrow-callback": "error",
        "quotes": ["error", "double", {"allowTemplateLiterals": true}],

        // The Google preset assumes 2-space indent and an 80-column limit. This
        // codebase is 4-space with longer lines throughout, and reformatting ~1900
        // lines of working Cloud Functions to satisfy a style preset is a worse
        // trade than matching the preset to the code. These three accounted for
        // essentially all 1198 pre-existing errors.
        "indent": ["error", 4, {SwitchCase: 1}],
        "max-len": ["error", {code: 120, ignoreUrls: true, ignoreTemplateLiterals: true, ignoreStrings: true}],
        "require-jsdoc": "off",
    },
    overrides: [
        {
            files: ["**/*.spec.*"],
            env: {
                mocha: true,
            },
            rules: {},
        },
    ],
    globals: {},
};
