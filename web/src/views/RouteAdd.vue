<template>
  <div>
    <div class="page-header">
      <div class="d-flex align-items-center gap-2 mb-1">
        <router-link to="/routes" class="text-muted text-decoration-none small">Routes</router-link>
        <span class="text-muted small">/</span>
        <span class="small">Add Route</span>
      </div>
      <h1>Add Route</h1>
    </div>

    <div class="row">
      <div class="col-md-8">
        <div class="card">
          <div class="card-body">
            <div v-if="error" class="alert alert-danger small py-2">{{ error }}</div>
            <div v-if="success" class="alert alert-success">
              Route added! <router-link to="/routes">View routes.</router-link>
            </div>

            <div class="mb-3">
              <label class="form-label fw-semibold">Flight Number</label>
              <input v-model="form.flight_number" type="text" class="form-control" placeholder="EZS1501" />
            </div>

            <div class="row mb-3">
              <div class="col-md-3">
                <label class="form-label fw-semibold">Departure ICAO</label>
                <input v-model="form.departure_icao" type="text" class="form-control" placeholder="LSGG" maxlength="4" />
              </div>
              <div class="col-md-9">
                <label class="form-label fw-semibold">Departure Name</label>
                <input v-model="form.departure_name" type="text" class="form-control" placeholder="Geneva" />
              </div>
            </div>

            <div class="row mb-3">
              <div class="col-md-3">
                <label class="form-label fw-semibold">Arrival ICAO</label>
                <input v-model="form.arrival_icao" type="text" class="form-control" placeholder="EGLL" maxlength="4" />
              </div>
              <div class="col-md-9">
                <label class="form-label fw-semibold">Arrival Name</label>
                <input v-model="form.arrival_name" type="text" class="form-control" placeholder="London Heathrow" />
              </div>
            </div>

            <div class="row mb-3">
              <div class="col-md-6">
                <label class="form-label fw-semibold">Distance (NM)</label>
                <input v-model.number="form.distance_nm" type="number" class="form-control" />
              </div>
              <div class="col-md-6">
                <label class="form-label fw-semibold">Estimated Time (HH:MM:SS)</label>
                <input v-model="form.estimated_time" type="text" class="form-control" placeholder="1:30:00" />
              </div>
            </div>

            <div class="form-check mb-3">
              <input v-model="form.is_active" type="checkbox" class="form-check-input" id="isActive" />
              <label class="form-check-label" for="isActive">Active route</label>
            </div>

            <div class="form-check mb-3">
              <input v-model="createReturn" type="checkbox" class="form-check-input" id="createReturn" />
              <label class="form-check-label" for="createReturn">Also create return route</label>
            </div>

            <button class="btn btn-primary" :disabled="!isValid || loading" @click="addRoute">
              {{ loading ? 'Adding...' : 'Add Route' }}
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
    const createReturn = ref(true)

    const form = reactive({
      flight_number: '',
      departure_icao: '',
      departure_name: '',
      arrival_icao: '',
      arrival_name: '',
      distance_nm: null,
      estimated_time: '',
      is_active: true
    })

    const isValid = computed(() =>
      form.flight_number && form.departure_icao && form.departure_name &&
      form.arrival_icao && form.arrival_name && form.distance_nm && form.estimated_time
    )

    const addRoute = async () => {
      loading.value = true
      error.value = ''
      success.value = false

      const routes = [{ ...form }]

      if (createReturn.value) {
        // Generate return flight number (increment last digit/number)
        const num = form.flight_number.match(/\d+/)
        const returnNum = num ? form.flight_number.replace(num[0], String(Number(num[0]) + 1)) : form.flight_number + 'R'
        routes.push({
          flight_number: returnNum,
          departure_icao: form.arrival_icao,
          departure_name: form.arrival_name,
          arrival_icao: form.departure_icao,
          arrival_name: form.departure_name,
          distance_nm: form.distance_nm,
          estimated_time: form.estimated_time,
          is_active: form.is_active
        })
      }

      const { error: err } = await supabase.from('routes').insert(routes)

      if (err) {
        error.value = err.message
      } else {
        success.value = true
        Object.assign(form, {
          flight_number: '', departure_icao: '', departure_name: '',
          arrival_icao: '', arrival_name: '', distance_nm: null, estimated_time: '', is_active: true
        })
      }
      loading.value = false
    }

    return { form, isValid, loading, error, success, createReturn, addRoute }
  }
}
</script>
