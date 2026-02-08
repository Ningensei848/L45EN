module.exports = (tp) => {
    const { getUsername, getDailyNoteDir } = tp.user.util()
    return {
        userId: getUsername(),
        dailyNoteDir: getDailyNoteDir()
    }
}
