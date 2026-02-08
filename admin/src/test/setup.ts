import '@testing-library/jest-dom/vitest'

class ResizeObserver {
  observe() {
    return undefined
  }

  unobserve() {
    return undefined
  }

  disconnect() {
    return undefined
  }
}

class MatchMediaEventTarget {
  matches = false
  media = ''
  onchange = null

  addEventListener() {
    return undefined
  }

  removeEventListener() {
    return undefined
  }

  dispatchEvent() {
    return false
  }
}

if (!window.ResizeObserver) {
  window.ResizeObserver = ResizeObserver as unknown as typeof window.ResizeObserver
}

if (!window.matchMedia) {
  window.matchMedia = () => new MatchMediaEventTarget() as unknown as MediaQueryList
}

const originalGetComputedStyle = window.getComputedStyle

window.getComputedStyle = ((element: Element, pseudoElt?: string) => {
  if (pseudoElt) {
    const pseudoStyle = {
      getPropertyValue: () => '',
    }

    return pseudoStyle as unknown as CSSStyleDeclaration
  }

  return originalGetComputedStyle(element)
}) as typeof window.getComputedStyle

// Mock localStorage for JSDOM
const localStorageData: Record<string, string> = {}

const localStorageMock = {
  getItem: vi.fn((key: string) => localStorageData[key] || null),
  setItem: vi.fn((key: string, value: string) => {
    localStorageData[key] = value.toString()
  }),
  removeItem: vi.fn((key: string) => {
    delete localStorageData[key]
  }),
  clear: vi.fn(() => {
    Object.keys(localStorageData).forEach((key) => delete localStorageData[key])
  }),
  get store() {
    return localStorageData
  },
}

Object.defineProperty(globalThis, 'localStorage', {
  value: localStorageMock,
  writable: true,
})
