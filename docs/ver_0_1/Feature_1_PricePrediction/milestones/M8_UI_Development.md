# Milestone 8: UI Development & Integration

**Duration:** Week 10-12 (12 working days)
**Team:** Frontend + Full Stack (2-3 developers)
**Dependencies:** M7 (API Gateway must be working)
**Status:** Not Started

---

## Objective

Build a modern, responsive web UI using Next.js 14 and React that displays real-time price predictions, allows users to search symbols, view prediction details with confidence intervals, request AI-powered explanations, and receive live updates via WebSocket. The UI must be intuitive, fast, and mobile-friendly.

---

## Success Criteria

- ✅ Dashboard loads in <2 seconds
- ✅ Real-time updates via WebSocket (no manual refresh)
- ✅ Responsive design (works on mobile, tablet, desktop)
- ✅ Search functionality with autocomplete
- ✅ Prediction details with charts and confidence intervals
- ✅ Explanation panel with AI-generated insights
- ✅ Error handling and loading states
- ✅ 90+ Lighthouse score (performance, accessibility)

---

## Task List

### 1. Next.js Project Setup
**Status:** Not Started

- [ ] **T1.1** - Initialize Next.js 14 project
  - [ ] Run `npx create-next-app@latest`
  - [ ] Choose: TypeScript, App Router, Tailwind CSS
  - [ ] Create `/app` directory structure
  - [ ] Set up folder structure: `/components`, `/lib`, `/hooks`, `/types`
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** M7 completion

- [ ] **T1.2** - Configure Tailwind CSS
  - [ ] Install and configure Tailwind
  - [ ] Create custom color palette (brand colors)
  - [ ] Configure responsive breakpoints
  - [ ] Set up typography plugin
  - [ ] Test with sample components
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T1.1

- [ ] **T1.3** - Set up state management (Zustand)
  - [ ] Install Zustand
  - [ ] Create stores: `usePredictionStore`, `useAuthStore`
  - [ ] Implement actions and selectors
  - [ ] Test state persistence (localStorage)
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.1

- [ ] **T1.4** - Configure API client
  - [ ] Create `/lib/api.ts` with fetch wrapper
  - [ ] Configure base URL from environment variables
  - [ ] Implement error handling
  - [ ] Add authentication headers (API key)
  - [ ] Test with API endpoints
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.3

---

### 2. Authentication & Authorization
**Status:** Not Started

- [ ] **T2.1** - Implement login page
  - [ ] Create `/app/login/page.tsx`
  - [ ] Design login form (email/password or API key)
  - [ ] Implement login logic (call API)
  - [ ] Store token in Zustand + localStorage
  - [ ] Redirect to dashboard on success
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T1.4

- [ ] **T2.2** - Implement authentication middleware
  - [ ] Create protected route wrapper
  - [ ] Check token validity on page load
  - [ ] Redirect to login if unauthenticated
  - [ ] Handle token expiration
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T2.1

- [ ] **T2.3** - Implement logout functionality
  - [ ] Create logout button in header
  - [ ] Clear token from Zustand + localStorage
  - [ ] Redirect to login page
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 1 hour
  - **Blocked by:** T2.2

---

### 3. Dashboard Page
**Status:** Not Started

- [ ] **T3.1** - Create dashboard layout
  - [ ] Create `/app/dashboard/page.tsx`
  - [ ] Design header with logo, search, user menu
  - [ ] Design main content area (grid layout)
  - [ ] Design sidebar (optional: watchlist, filters)
  - [ ] Make responsive (mobile, tablet, desktop)
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T2.2

- [ ] **T3.2** - Implement search bar with autocomplete
  - [ ] Create `SearchBar` component
  - [ ] Implement debounced search (500ms)
  - [ ] Call API or use local symbol list for autocomplete
  - [ ] Show dropdown with matching symbols
  - [ ] Navigate to symbol detail on selection
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 5 hours
  - **Blocked by:** T3.1

- [ ] **T3.3** - Create prediction card component
  - [ ] Create `PredictionCard.tsx`
  - [ ] Display: symbol, current price, predicted price, predicted return
  - [ ] Color code: green (positive), red (negative)
  - [ ] Show confidence interval (90% CI)
  - [ ] Show timestamp and freshness indicator
  - [ ] Make clickable to navigate to detail page
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.1

- [ ] **T3.4** - Implement watchlist (grid of prediction cards)
  - [ ] Create `Watchlist` component
  - [ ] Load initial watchlist (default: top 20 symbols)
  - [ ] Display prediction cards in grid (responsive)
  - [ ] Allow adding/removing symbols from watchlist
  - [ ] Persist watchlist to localStorage
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 5 hours
  - **Blocked by:** T3.3

- [ ] **T3.5** - Implement market overview section
  - [ ] Show S&P 500 index current value
  - [ ] Show market sentiment indicator
  - [ ] Show number of symbols with fresh predictions
  - [ ] Show system status (all green or warnings)
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T3.4

---

### 4. Symbol Detail Page
**Status:** Not Started

- [ ] **T4.1** - Create symbol detail page layout
  - [ ] Create `/app/symbol/[symbol]/page.tsx`
  - [ ] Design layout: header, price chart, prediction card, explanation panel
  - [ ] Make responsive
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T3.5

- [ ] **T4.2** - Implement price chart component
  - [ ] Use `recharts` or `TradingView Lightweight Charts`
  - [ ] Show historical price (last 30 days)
  - [ ] Show predicted price as dashed line
  - [ ] Show confidence interval as shaded area
  - [ ] Add zoom and pan controls
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 6 hours
  - **Blocked by:** T4.1

- [ ] **T4.3** - Implement prediction detail card
  - [ ] Show current price, predicted price, predicted return
  - [ ] Show uncertainty (sigma)
  - [ ] Show percentiles (p10, p50, p90) as table
  - [ ] Show model type (normal_day or earnings_day)
  - [ ] Show prediction timestamp
  - [ ] Show data freshness
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.1

- [ ] **T4.4** - Implement "Explain" button and explanation panel
  - [ ] Add "Explain This Prediction" button
  - [ ] On click, call POST /api/explanation/{symbol}
  - [ ] Show loading spinner while generating
  - [ ] Poll GET /api/explanation/{symbol} until ready
  - [ ] Display explanation text in expandable panel
  - [ ] Show key drivers as bullet points
  - [ ] Show uncertainties as bullet points
  - [ ] Show sources/citations as links
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 6 hours
  - **Blocked by:** T4.3

- [ ] **T4.5** - Implement technical features table
  - [ ] Show all 20 technical features in collapsible table
  - [ ] Format values (percentages, decimals)
  - [ ] Add tooltips explaining each feature
  - [ ] Highlight features that are outliers
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T4.3

- [ ] **T4.6** - Implement earnings context (if earnings day)
  - [ ] Show earnings-specific features (EPS surprise, revenue surprise)
  - [ ] Show fundamental metrics (margins, growth)
  - [ ] Show historical earnings pattern
  - [ ] Only show if `model_type === "earnings_day"`
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T4.5

---

### 5. Real-Time Updates (WebSocket)
**Status:** Not Started

- [ ] **T5.1** - Implement WebSocket hook
  - [ ] Create `/hooks/useWebSocket.ts`
  - [ ] Connect to `ws://api/ws/predictions`
  - [ ] Send authentication token
  - [ ] Handle connection lifecycle (connect, disconnect, error)
  - [ ] Implement reconnection logic (exponential backoff)
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 5 hours
  - **Blocked by:** T1.4

- [ ] **T5.2** - Implement subscription management
  - [ ] Send subscribe message with symbols
  - [ ] Send unsubscribe message when leaving page
  - [ ] Handle subscription updates (add/remove symbols dynamically)
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T5.1

- [ ] **T5.3** - Integrate WebSocket updates in Dashboard
  - [ ] Use `useWebSocket` hook in watchlist
  - [ ] Subscribe to symbols in watchlist
  - [ ] Update prediction cards when new data arrives
  - [ ] Show visual indicator (flash/pulse) on update
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.2, T3.4

- [ ] **T5.4** - Integrate WebSocket updates in Symbol Detail
  - [ ] Subscribe to current symbol
  - [ ] Update prediction card in real-time
  - [ ] Update price chart with new data point
  - [ ] Show "Live" badge when receiving updates
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 4 hours
  - **Blocked by:** T5.3, T4.4

---

### 6. Loading States & Error Handling
**Status:** Not Started

- [ ] **T6.1** - Create loading components
  - [ ] Create `Spinner` component
  - [ ] Create skeleton loaders for prediction cards
  - [ ] Create skeleton loader for chart
  - [ ] Create loading overlay for full page
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.2

- [ ] **T6.2** - Implement error handling
  - [ ] Create `ErrorMessage` component
  - [ ] Handle API errors (404, 500, network errors)
  - [ ] Show user-friendly error messages
  - [ ] Add "Retry" button for transient errors
  - [ ] Log errors to console (or error tracking service)
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T6.1

- [ ] **T6.3** - Implement empty states
  - [ ] Show message when no symbols in watchlist
  - [ ] Show message when symbol not found
  - [ ] Show message when prediction not available
  - [ ] Add helpful action buttons (e.g., "Add symbols")
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T6.2

---

### 7. Responsive Design & Accessibility
**Status:** Not Started

- [ ] **T7.1** - Implement mobile-first responsive design
  - [ ] Test all pages on mobile (320px-480px)
  - [ ] Test on tablet (768px-1024px)
  - [ ] Test on desktop (1280px+)
  - [ ] Adjust layouts, font sizes, spacing
  - [ ] Use Tailwind responsive utilities
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 6 hours
  - **Blocked by:** T4.6, T5.4

- [ ] **T7.2** - Implement accessibility (WCAG 2.1 AA)
  - [ ] Add semantic HTML (header, nav, main, footer)
  - [ ] Add ARIA labels and roles
  - [ ] Ensure keyboard navigation works
  - [ ] Add focus indicators
  - [ ] Ensure color contrast meets WCAG standards
  - [ ] Test with screen reader (NVDA or VoiceOver)
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T7.1

- [ ] **T7.3** - Implement dark mode (optional enhancement)
  - [ ] Add dark mode toggle in header
  - [ ] Define dark color palette in Tailwind
  - [ ] Apply dark mode classes to all components
  - [ ] Persist preference to localStorage
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T7.2

---

### 8. Performance Optimization
**Status:** Not Started

- [ ] **T8.1** - Implement code splitting
  - [ ] Use Next.js dynamic imports for large components
  - [ ] Lazy load chart library
  - [ ] Lazy load explanation panel
  - [ ] Measure bundle size reduction
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T7.3

- [ ] **T8.2** - Optimize images
  - [ ] Use Next.js `<Image>` component
  - [ ] Optimize logo and icons (WebP format)
  - [ ] Implement lazy loading for images
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T8.1

- [ ] **T8.3** - Implement caching strategies
  - [ ] Cache API responses (SWR or React Query)
  - [ ] Implement stale-while-revalidate pattern
  - [ ] Cache static assets (logo, fonts)
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 3 hours
  - **Blocked by:** T8.2

- [ ] **T8.4** - Run Lighthouse audit
  - [ ] Test on dashboard page
  - [ ] Test on symbol detail page
  - [ ] Target: 90+ score (performance, accessibility, SEO)
  - [ ] Document results and optimizations
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T8.3

---

### 9. Additional Features
**Status:** Not Started

- [ ] **T9.1** - Implement settings page
  - [ ] Create `/app/settings/page.tsx`
  - [ ] Allow user to configure watchlist
  - [ ] Allow user to set notification preferences
  - [ ] Allow user to change theme (dark mode)
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T7.3

- [ ] **T9.2** - Implement about/help page
  - [ ] Create `/app/about/page.tsx`
  - [ ] Explain what the system does
  - [ ] Disclaimer: "Not financial advice"
  - [ ] FAQ section
  - [ ] Contact information
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T9.1

- [ ] **T9.3** - Implement notification system (toasts)
  - [ ] Install toast library (react-hot-toast or sonner)
  - [ ] Show toast on prediction update
  - [ ] Show toast on explanation ready
  - [ ] Show toast on errors
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 2 hours
  - **Blocked by:** T6.2

---

### 10. Testing
**Status:** Not Started

- [ ] **T10.1** - Set up testing framework
  - [ ] Install Jest and React Testing Library
  - [ ] Configure test environment
  - [ ] Create test utilities (mock providers)
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 3 hours
  - **Blocked by:** T1.1

- [ ] **T10.2** - Write component unit tests
  - [ ] Test `PredictionCard` component
  - [ ] Test `SearchBar` component
  - [ ] Test `Watchlist` component
  - [ ] Test `ErrorMessage` component
  - [ ] Target: >70% code coverage
  - **Assigned to:** Frontend Dev 1, Frontend Dev 2
  - **Estimated time:** 8 hours
  - **Blocked by:** T10.1

- [ ] **T10.3** - Write integration tests
  - [ ] Test dashboard page loads
  - [ ] Test symbol detail page loads
  - [ ] Test search functionality
  - [ ] Test explanation request flow
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 6 hours
  - **Blocked by:** T10.2

- [ ] **T10.4** - Write E2E tests (Playwright or Cypress)
  - [ ] Test user login flow
  - [ ] Test search and navigate to symbol
  - [ ] Test request explanation
  - [ ] Test WebSocket real-time updates
  - **Assigned to:** Full Stack Dev
  - **Estimated time:** 8 hours
  - **Blocked by:** T10.3

- [ ] **T10.5** - Cross-browser testing
  - [ ] Test on Chrome, Firefox, Safari, Edge
  - [ ] Test on iOS Safari, Android Chrome
  - [ ] Document browser compatibility
  - [ ] Fix any browser-specific issues
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 4 hours
  - **Blocked by:** T10.4

---

### 11. Deployment
**Status:** Not Started

- [ ] **T11.1** - Configure environment variables
  - [ ] Create `.env.local` for development
  - [ ] Create `.env.production` for production
  - [ ] Configure API base URL
  - [ ] Configure WebSocket URL
  - [ ] Document all environment variables
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 1 hour
  - **Blocked by:** T1.1

- [ ] **T11.2** - Set up deployment to Vercel
  - [ ] Connect GitHub repository to Vercel
  - [ ] Configure build settings
  - [ ] Set environment variables in Vercel
  - [ ] Configure custom domain (optional)
  - [ ] Test deployment
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 3 hours
  - **Blocked by:** T11.1

- [ ] **T11.3** - Create Docker image for UI (alternative)
  - [ ] Create Dockerfile with Node.js
  - [ ] Build Next.js app for production
  - [ ] Serve with standalone server
  - [ ] Add health check
  - [ ] Test Docker image
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 4 hours
  - **Blocked by:** T11.1

- [ ] **T11.4** - Add UI to docker-compose (alternative)
  - [ ] Add service definition to `docker-compose.yml`
  - [ ] Expose port 3000
  - [ ] Configure environment variables
  - [ ] Test full stack locally
  - **Assigned to:** DevOps Lead
  - **Estimated time:** 2 hours
  - **Blocked by:** T11.3

---

### 12. Documentation
**Status:** Not Started

- [ ] **T12.1** - Create UI component documentation
  - [ ] Document reusable components
  - [ ] Add PropTypes or TypeScript interfaces
  - [ ] Add usage examples
  - [ ] Consider Storybook (optional)
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 4 hours
  - **Blocked by:** T9.3

- [ ] **T12.2** - Create user guide
  - [ ] How to search for symbols
  - [ ] How to view predictions
  - [ ] How to request explanations
  - [ ] How to customize watchlist
  - [ ] Add screenshots
  - **Assigned to:** Frontend Dev 2
  - **Estimated time:** 3 hours
  - **Blocked by:** T12.1

- [ ] **T12.3** - Create developer documentation
  - [ ] How to run locally
  - [ ] How to build for production
  - [ ] How to deploy
  - [ ] Architecture overview
  - **Assigned to:** Frontend Dev 1
  - **Estimated time:** 2 hours
  - **Blocked by:** T12.2

---

## Deliverables

1. ✅ **Dashboard** - Search, watchlist, market overview
2. ✅ **Symbol Detail Page** - Price chart, prediction details, explanation
3. ✅ **Real-Time Updates** - WebSocket integration
4. ✅ **Responsive Design** - Mobile, tablet, desktop
5. ✅ **Authentication** - Login/logout functionality
6. ✅ **Error Handling** - User-friendly error messages
7. ✅ **Test Suite** - Unit, integration, E2E tests
8. ✅ **Deployment** - Vercel or Docker
9. ✅ **Documentation** - User guide, developer docs

---

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| WebSocket connection issues | Implement reconnection logic, fallback to polling |
| Slow chart rendering | Use lightweight chart library, optimize data points |
| Mobile performance issues | Lazy load components, optimize images, code splitting |
| Cross-browser compatibility | Test early and often, use polyfills where needed |
| Accessibility issues | Use semantic HTML, ARIA, test with screen readers |

---

## Acceptance Criteria

- [ ] Dashboard loads in <2 seconds
- [ ] Real-time updates work via WebSocket
- [ ] Responsive on mobile, tablet, desktop
- [ ] Search with autocomplete works
- [ ] Symbol detail page shows chart, prediction, explanation
- [ ] Error handling shows user-friendly messages
- [ ] Lighthouse score 90+ (performance, accessibility)
- [ ] All tests passing (unit, integration, E2E)
- [ ] Cross-browser compatible (Chrome, Firefox, Safari, Edge)
- [ ] Documentation complete (user guide, developer docs)

---

## Definition of Done

- [ ] All tasks marked as "Done"
- [ ] Code reviewed and merged to `develop` branch
- [ ] Test coverage >70%
- [ ] Lighthouse score 90+ on all pages
- [ ] Cross-browser testing completed
- [ ] E2E tests passing
- [ ] Deployed to Vercel or Docker
- [ ] Documentation complete
- [ ] Demo completed with stakeholders
- [ ] Product Owner sign-off

---

**Milestone Owner:** Frontend Dev 1
**Review Date:** End of Week 12
**Next Milestone:** M9 - Testing, Monitoring & Deployment

[End of Milestone 8]
