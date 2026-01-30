// Infinite scroll hook for LiveView
// Triggers "load-more" event when sentinel element enters viewport

const InfiniteScroll = {
  mounted() {
    this.observer = new IntersectionObserver(
      (entries) => {
        const entry = entries[0];
        if (entry.isIntersecting && !this.el.dataset.loading) {
          this.el.dataset.loading = "true";
          this.pushEvent("load-more", {});
        }
      },
      {
        root: null,
        rootMargin: "200px", // Start loading before hitting the bottom
        threshold: 0.1,
      }
    );
    this.observer.observe(this.el);
  },

  updated() {
    // Reset loading state when LiveView updates
    delete this.el.dataset.loading;
  },

  destroyed() {
    if (this.observer) {
      this.observer.disconnect();
    }
  },
};

export default InfiniteScroll;
