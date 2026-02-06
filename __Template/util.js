function getUsername() {
    // 1. Windows Username を取得
    let userId = process.env.USERNAME;
    // 2. 取得できなかった場合、%USERPROFILE% の末尾要素を使う
    if (typeof userId !== "string" || !userId.length) {
        const profile = process.env.USERPROFILE;
        if (typeof profile === "string" && profile.length){
        const leaf = profile.split(/[\\/]/);
        userId = leaf[leaf.length - 1];
        }
    }
    // Finally, ...
    return userId
}

function getDailyNoteDir() {
    const dailyNotesPlugin = app.internalPlugins.plugins["daily-notes"];
    const options = dailyNotesPlugin?.instance?.options
    return options?.folder || "";
}

module.exports = () => ({
    getUsername,
    getDailyNoteDir
});
