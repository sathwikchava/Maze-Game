const Hooks = {
    VideoHandler: {
    mounted() {
        const video = this.el;
            video.addEventListener('loadeddata', () => {
        console.log("Video loaded");
        });
            video.addEventListener('error', (e) => {
    console.log("Video error:", e);
        });
            // Force play on mount
        video.play().catch(function(error) {
        console.log("Video play failed:", error);
        });
    }
    }
}
export default Hooks;