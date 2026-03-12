<template>
  <div>
    <div class="page-header">
      <div class="d-flex align-items-center gap-2 mb-1">
        <router-link to="/fleet" class="text-muted text-decoration-none small">Fleet</router-link>
        <span class="text-muted small">/</span>
        <span class="small">Add Aircraft</span>
      </div>
      <h1>Add Aircraft</h1>
    </div>

    <div class="row">
      <div class="col-md-8">
        <div class="card">
          <div class="card-body">
            <div v-if="error" class="alert alert-danger small py-2">{{ error }}</div>
            <div v-if="success" class="alert alert-success">
              Aircraft added! <router-link to="/fleet">View fleet.</router-link>
            </div>

            <div class="row mb-3">
              <div class="col-md-6">
                <label class="form-label fw-semibold">Registration</label>
                <input v-model="form.registration" type="text" class="form-control" placeholder="HB-JXK" />
              </div>
              <div class="col-md-6">
                <label class="form-label fw-semibold">ICAO Type</label>
                <input v-model="form.icao_type" type="text" class="form-control" placeholder="A320" />
              </div>
            </div>

            <div class="mb-3">
              <label class="form-label fw-semibold">Full Type Name</label>
              <input v-model="form.type" type="text" class="form-control" placeholder="Airbus A320-214" />
            </div>

            <div class="mb-3">
              <label class="form-label fw-semibold">Livery</label>
              <input v-model="form.livery" type="text" class="form-control" placeholder="EasyJet Switzerland" />
            </div>

            <div class="row mb-3">
              <div class="col-md-4">
                <label class="form-label fw-semibold">Home Base</label>
                <select v-model="form.home_base" class="form-select">
                  <option value="LSGG">LSGG - Geneva</option>
                  <option value="LSZH">LSZH - Zurich</option>
                  <option value="LSBS">LSBS - Basel</option>
                </select>
              </div>
              <div class="col-md-4">
                <label class="form-label fw-semibold">Seat Capacity</label>
                <input v-model.number="form.seat_capacity" type="number" class="form-control" />
              </div>
              <div class="col-md-4">
                <label class="form-label fw-semibold">Status</label>
                <select v-model="form.status" class="form-select">
                  <option value="active">Active</option>
                  <option value="maintenance">Maintenance</option>
                  <option value="retired">Retired</option>
                </select>
              </div>
            </div>

            <button
              class="btn btn-primary"
              :disabled="!isValid || loading"
              @click="addAircraft"
            >
              {{ loading ? 'Adding...' : 'Add Aircraft' }}
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script>
import { ref, reactive, computed } from 'vue'
import { supabase } from '../lib/supabase'

export default {
  setup() {
    const loading = ref(false)
    const error = ref('')
    const success = ref(false)

    const form = reactive({
      registration: '',
      type: '',
      icao_type: '',
      livery: 'EasyJet Switzerland',
      home_base: 'LSGG',
      seat_capacity: 186,
      status: 'active'
    })

    const isValid = computed(() => form.registration && form.type && form.icao_type)

    const addAircraft = async () => {
      loading.value = true
      error.value = ''
      success.value = false

      const { error: err } = await supabase.from('aircraft').insert({ ...form })

      if (err) {
        error.value = err.message
      } else {
        success.value = true
        Object.assign(form, {
          registration: '', type: '', icao_type: '',
          livery: 'EasyJet Switzerland', home_base: 'LSGG', seat_capacity: 186, status: 'active'
        })
      }
      loading.value = false
    }

    return { form, isValid, loading, error, success, addAircraft }
  }
}
</script>
