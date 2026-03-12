<template>
  <div id="app">
    <Navbar v-if="session" />
    <div v-if="session" class="content-wrapper">
      <router-view :key="$route.fullPath" />
    </div>
    <router-view v-else />
  </div>
</template>

<script>
import { ref, onMounted } from 'vue'
import { supabase } from './lib/supabase'
import Navbar from './components/Navbar.vue'

export default {
  components: { Navbar },
  setup() {
    const session = ref(null)

    onMounted(() => {
      supabase.auth.getSession().then(({ data }) => {
        session.value = data.session
      })

      supabase.auth.onAuthStateChange((_event, s) => {
        session.value = s
      })
    })

    return { session }
  }
}
</script>
