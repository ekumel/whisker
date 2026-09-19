pragma Singleton

import QtQuick
import Quickshell
import Quickshell.Io
import qs.preferences

// i18n module. Provides lookup of translated strings from JSON catalogs
// located under `modules/translations/`.
//
// Usage:
//     import qs.modules
//     Text { text: Translations.tr("weather.clear_sky") }
//     Text { text: Translations.tr("weather.feels_like", "21°C") }
//
// Translation files are JSON objects keyed by dotted paths. Placeholders use
// `{0}`, `{1}`, `{2}` and are substituted with positional arguments passed
// to `tr()`. Up to three positional args are supported.
Singleton {
    id: root

    // Available language codes. Add a new entry here (and drop a matching
    // `<code>.json` under modules/translations/) to ship another language.
    readonly property var availableLanguages: ["en", "zh"]

    // Current language code (e.g. "en", "zh"). Defaults to "en" and is
    // updated automatically from the system locale on first launch.
    property string currentLanguage: "en"

    // Bumped whenever the active language changes so that bindings depending
    // on `tr()` re-evaluate automatically.
    property int revision: 0

    // Loaded catalogs. Each entry is the parsed JSON object for a language.
    property var catalogs: ({})

    // Display name for the active language (falls back to the code).
    readonly property string currentLanguageName: {
        const cat = catalogs[currentLanguage];
        return (cat && cat._meta && cat._meta.name) || currentLanguage;
    }

    signal languageChanged(string language)

    readonly property string translationsDir: Quickshell.shellDir + "/modules/translations"

    Component.onCompleted: applyPreferredOrDetected()

    // React to changes in the saved language preference. `Preferences` loads
    // asynchronously from disk via a FileView, so this connection fires once
    // the preferences file has been parsed.
    Connections {
        target: Preferences
        function onReloaded() { root.applyPreferredOrDetected() }
    }

    function applyPreferredOrDetected() {
        const pref = Preferences.misc.language;
        // Empty preference means "follow system". Unknown codes also fall
        // back to system detection so a removed/typo'd language never leaves
        // the UI stuck on an unavailable catalog.
        if (pref && pref !== "" && availableLanguages.indexOf(pref) !== -1) {
            if (currentLanguage !== pref) {
                currentLanguage = pref;
                revision++;
                root.languageChanged(pref);
            }
        } else {
            detectSystemLocale();
        }
    }

    // Resolves the system locale to a supported language. Falls back to
    // English when the system language has no catalog.
    function detectSystemLocale() {
        const loc = (Qt.locale().name || "").toLowerCase();
        let target = "en";
        for (let i = 0; i < availableLanguages.length; i++) {
            const code = availableLanguages[i];
            if (code !== "en" && (loc === code || loc.startsWith(code + "_") || loc.startsWith(code + "-"))) {
                target = code;
                break;
            }
        }
        if (currentLanguage === target)
            return;
        currentLanguage = target;
        revision++;
        root.languageChanged(target);
    }

    // Look up `key` (a dotted path like "weather.clear_sky") in the catalog
    // for `currentLanguage`. Falls back to English, then to the key itself,
    // if the entry is missing. Up to three positional args are substituted
    // into `{0}`, `{1}`, `{2}` placeholders. Reads `revision` so bindings
    // refresh on language change.
    function tr(key, a0, a1, a2) {
        // Touch revision so this binding re-evaluates on language change.
        const _ = root.revision;

        const value = lookup(currentLanguage, key);
        if (value !== undefined && value !== null)
            return format(value, [a0, a1, a2]);

        // Fallback to English.
        if (currentLanguage !== "en") {
            const enValue = lookup("en", key);
            if (enValue !== undefined && enValue !== null)
                return format(enValue, [a0, a1, a2]);
        }

        // Nothing matched — return the key so it's obvious what's missing.
        return key;
    }

    // Convenience: returns the active display name of a language code.
    function languageName(code) {
        const cat = catalogs[code];
        return (cat && cat._meta && cat._meta.name) || code;
    }

    // Switch the active language. Empty / null is treated as auto-detect.
    function setLanguage(code) {
        if (!code || code === "") {
            detectSystemLocale();
            return;
        }
        if (code === currentLanguage)
            return;
        currentLanguage = code;
        revision++;
        root.languageChanged(code);
    }

    function lookup(lang, key) {
        const cat = catalogs[lang];
        if (!cat)
            return undefined;

        const parts = String(key).split(".");
        let node = cat;
        for (let i = 0; i < parts.length; i++) {
            if (node === null || node === undefined || typeof node !== "object")
                return undefined;
            node = node[parts[i]];
        }
        return node;
    }

    function format(template, args) {
        if (!args || args.length === 0)
            return String(template);

        let out = String(template);
        for (let i = 0; i < args.length; i++) {
            const v = args[i];
            // Skip placeholders that weren't supplied. Leaves the {n} in
            // place so missing values are obvious during development.
            if (v === undefined)
                continue;
            out = out.split("{" + i + "}").join(String(v));
        }
        return out;
    }

    function _onCatalogLoaded(code, text) {
        if (!text || text === "")
            return;
        try {
            const parsed = JSON.parse(text);
            const next = Object.assign({}, catalogs);
            next[code] = parsed;
            catalogs = next;
        } catch (e) {
            console.warn("Translations: failed to parse", code, e);
        }
    }

    // One FileView per supported language. Catalog updates flow through
    // _onCatalogLoaded and the binding-friendly `catalogs` property.
    FileView {
        path: root.translationsDir + "/en.json"
        onLoaded: root._onCatalogLoaded("en", text())
    }

    FileView {
        path: root.translationsDir + "/zh.json"
        onLoaded: root._onCatalogLoaded("zh", text())
    }
}