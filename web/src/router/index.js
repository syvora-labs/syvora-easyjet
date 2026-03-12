import { createRouter, createWebHistory } from 'vue-router'
import { supabase } from '../lib/supabase'

const routes = [
  {
    path: '/login',
    name: 'Login',
    component: () => import('../views/Login.vue'),
    meta: { requiresAuth: false }
  },
  {
    path: '/',
    name: 'Dashboard',
    component: () => import('../views/Dashboard.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/fleet',
    name: 'Fleet',
    component: () => import('../views/Fleet.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/fleet/add',
    name: 'AircraftAdd',
    component: () => import('../views/AircraftAdd.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/fleet/:id',
    name: 'AircraftDetail',
    component: () => import('../views/AircraftDetail.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/bookings',
    name: 'Bookings',
    component: () => import('../views/Bookings.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/bookings/new',
    name: 'NewBooking',
    component: () => import('../views/NewBooking.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/pireps',
    name: 'PIREPs',
    component: () => import('../views/Pireps.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/pireps/file',
    name: 'FilePIREP',
    component: () => import('../views/FilePirep.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/profile',
    name: 'Profile',
    component: () => import('../views/Profile.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/routes',
    name: 'Routes',
    component: () => import('../views/Routes.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/routes/add',
    name: 'RouteAdd',
    component: () => import('../views/RouteAdd.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/pireps',
    name: 'AdminPireps',
    component: () => import('../views/AdminPireps.vue'),
    meta: { requiresAuth: true }
  },
  {
    path: '/admin/pilots',
    name: 'AdminPilots',
    component: () => import('../views/AdminPilots.vue'),
    meta: { requiresAuth: true }
  }
]

const router = createRouter({
  history: createWebHistory(),
  routes
})

router.beforeEach(async (to, from, next) => {
  const { data: { session } } = await supabase.auth.getSession()

  if (to.meta.requiresAuth && !session) {
    next('/login')
  } else if (to.path === '/login' && session) {
    next('/')
  } else {
    next()
  }
})

export default router
