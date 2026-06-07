export const MultiSelect = {
  mounted() {
    this.el.addEventListener("mousedown", (e) => {
      e.preventDefault();
      let option = e.target;
      option.selected = !option.selected;

      this.el.dispatchEvent(new Event("change", { bubbles: true }));
    });
  },
};
