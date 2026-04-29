export const TutorialSpotlight = {
  updated() {
    const selector = this.el.dataset.highlight;
    if (!selector) return;
    const target = document.querySelector(selector);
    if (!target) return;
    target.scrollIntoView({ behavior: "smooth", block: "center" });
    target.classList.add(
      "ring-4",
      "ring-indigo-500",
      "ring-offset-2",
      "relative",
      "z-[60]",
    );
  },
};
