export const AutoFade = {
  mounted() {
    const delay = parseInt(this.el.dataset.fadeDelay) || 5000;

    this.timer = setTimeout(() => {
      this.el.style.opacity = "0";
      setTimeout(() => {
        this.pushEvent("lv:clear-flash", {
          key: this.el.id.replace("flash-", ""),
        });
      }, 500);
    }, delay);
  },

  destroyed() {
    if (this.timer) {
      clearTimeout(this.timer);
    }
  },
};

// export default AutoFade;
