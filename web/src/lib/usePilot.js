import { ref } from 'vue'
import { supabase } from './supabase'

const currentPilot = ref(null)
const loading = ref(false)
const loaded = ref(false)

export function usePilot() {
  const fetchPilot = async (force = false) => {
    if (loaded.value && !force) return currentPilot.value
    loading.value = true

    const { data: { user } } = await supabase.auth.getUser()
    if (!user) {
      loading.value = false
      return null
    }

    const { data } = await supabase
      .from('pilots')
      .select('*')
      .eq('user_id', user.id)
      .single()

    currentPilot.value = data
    loaded.value = true
    loading.value = false
    return data
  }

  const isAdmin = () => currentPilot.value?.rank === 'Admin'

  const clear = () => {
    currentPilot.value = null
    loaded.value = false
  }

  return { pilot: currentPilot, loading, fetchPilot, isAdmin, clear }
}
