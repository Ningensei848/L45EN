const findPrevNote = async (tp, isEmbed = false) => {
    // --- 設定 ---
    const { userId, dailyNoteDir } = tp.user.config(tp);
    const maxLookback = 180; // 約半年間までは遡って過去ノートを探す
    // -----------

    // 基準日の決定
    let anchorDate = moment();
    const [year, month, day]  = tp.date.now("YYYY-MM-DD").split("-");
    const parsedDate = moment(`${year}${month}${day}`, "YYYYMMDD", true);

    if (parsedDate.isValid()) {
        anchorDate = parsedDate;
    }

    // 探索ループ
    for (let i = 1; i <= maxLookback; i++) {
        const pastDate = moment(anchorDate).subtract(i, 'days');

        const yyyy = pastDate.format("YYYY");
        const mm = pastDate.format("MM");
        const yyyymmdd = pastDate.format("YYYYMMDD");

        const relativePath = `${dailyNoteDir}/${yyyy}/${mm}/${yyyymmdd}_${userId}.md`;

        // ファイル存在確認
        const file = app.vault.getAbstractFileByPath(relativePath);
        if (!file){
            // ファイルがなければ早期に次のループへ
            continue
        }

        const linkPath = relativePath.replace(".md", "");

        // 文字列として埋め込みリンクを返す
        if (isEmbed){
            return typeof isEmbed === 'string'
                ? `![[${linkPath}#${isEmbed}|${pastDate.format("YYYY-MM-DD")}]]`
                : `![[${linkPath}|${pastDate.format("YYYY-MM-DD")}]]`
        }
        // 文字列として、単なる内部リンクを返す
        return `[[${linkPath}|${pastDate.format("YYYY-MM-DD")}]]`
    }

    return "前回のノートなし";
}

// Finally, ...
module.exports = {
    // call: tp.user.daily.findPrevNote(tp)
    findPrevNote,
}
