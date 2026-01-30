# DaisyUI Reference for Chorus

DaisyUI is included with Phoenix 1.8+ and provides Tailwind CSS components.

## Documentation

- Official docs: https://daisyui.com/components/
- Theme generator: https://daisyui.com/theme-generator/

## Common Components

### Buttons
```html
<button class="btn">Default</button>
<button class="btn btn-primary">Primary</button>
<button class="btn btn-secondary">Secondary</button>
<button class="btn btn-accent">Accent</button>
<button class="btn btn-ghost">Ghost</button>
<button class="btn btn-link">Link</button>

<!-- Sizes -->
<button class="btn btn-lg">Large</button>
<button class="btn btn-sm">Small</button>
<button class="btn btn-xs">Tiny</button>
```

### Cards
```html
<div class="card bg-base-200 shadow-xl">
  <div class="card-body">
    <h2 class="card-title">Title</h2>
    <p>Content</p>
    <div class="card-actions justify-end">
      <button class="btn btn-primary">Action</button>
    </div>
  </div>
</div>
```

### Badges
```html
<span class="badge">Default</span>
<span class="badge badge-primary">Primary</span>
<span class="badge badge-secondary">Secondary</span>
<span class="badge badge-lg">Large</span>
<span class="badge badge-sm">Small</span>
```

### Alerts
```html
<div class="alert">Default alert</div>
<div class="alert alert-info">Info</div>
<div class="alert alert-success">Success</div>
<div class="alert alert-warning">Warning</div>
<div class="alert alert-error">Error</div>
```

### Form Inputs
```html
<input type="text" class="input input-bordered w-full" placeholder="Text" />
<input type="text" class="input input-primary" />
<textarea class="textarea textarea-bordered"></textarea>
<select class="select select-bordered">
  <option>Option 1</option>
</select>
<input type="checkbox" class="checkbox" />
<input type="checkbox" class="toggle" />
```

### Loading States
```html
<span class="loading loading-spinner"></span>
<span class="loading loading-dots"></span>
<span class="loading loading-ring"></span>
<span class="loading loading-bars"></span>
```

### Tables
```html
<table class="table">
  <thead>
    <tr><th>Name</th><th>Value</th></tr>
  </thead>
  <tbody>
    <tr><td>Item</td><td>123</td></tr>
  </tbody>
</table>
```

### Navigation
```html
<!-- Tabs -->
<div class="tabs tabs-boxed">
  <a class="tab">Tab 1</a>
  <a class="tab tab-active">Tab 2</a>
</div>

<!-- Breadcrumbs -->
<div class="breadcrumbs text-sm">
  <ul>
    <li><a>Home</a></li>
    <li><a>Documents</a></li>
  </ul>
</div>
```

### Modal
```html
<dialog id="my_modal" class="modal">
  <div class="modal-box">
    <h3 class="text-lg font-bold">Title</h3>
    <p class="py-4">Content</p>
    <div class="modal-action">
      <form method="dialog">
        <button class="btn">Close</button>
      </form>
    </div>
  </div>
</dialog>
```

## Theme Colors

DaisyUI uses semantic color names:
- `primary` - Main brand color
- `secondary` - Secondary brand color
- `accent` - Accent color
- `neutral` - Neutral gray
- `base-100/200/300` - Background colors
- `base-content` - Text on base colors
- `info/success/warning/error` - Status colors

## Usage in Phoenix

Components are used with Tailwind classes directly in HEEx templates:

```heex
<button class="btn btn-primary" phx-click="action">Click me</button>
```

For forms, use Phoenix's `<.input>` component with DaisyUI classes:

```heex
<.input field={@form[:name]} type="text" class="input input-bordered" />
```
