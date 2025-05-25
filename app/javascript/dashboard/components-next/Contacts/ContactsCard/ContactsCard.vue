<script setup>
import { ref, computed, watch } from 'vue';
import { useI18n } from 'vue-i18n';

import CardLayout from 'dashboard/components-next/CardLayout.vue';
import ContactsForm from 'dashboard/components-next/Contacts/ContactsForm/ContactsForm.vue';
import Button from 'dashboard/components-next/button/Button.vue';
import Avatar from 'dashboard/components-next/avatar/Avatar.vue';
import Flag from 'dashboard/components-next/flag/Flag.vue';
import countries from 'shared/constants/countries';
import Icon from 'dashboard/components-next/icon/Icon.vue';
import { createJwtToken, login3C } from 'dashboard/api/m3c.js';

const props = defineProps({
  id: { type: Number, required: true },
  name: { type: String, default: '' },
  email: { type: String, default: '' },
  additionalAttributes: { type: Object, default: () => ({}) },
  phoneNumber: { type: String, default: '' },
  thumbnail: { type: String, default: '' },
  isExpanded: { type: Boolean, default: false },
  isUpdating: { type: Boolean, default: false },
});

const emit = defineEmits(['toggle', 'updateContact', 'showContact']);

const { t } = useI18n();

const contactsFormRef = ref(null);
const popupUrl = ref(null);

const getInitialContactData = () => ({
  id: props.id,
  name: props.name,
  email: props.email,
  phoneNumber: props.phoneNumber,
  additionalAttributes: props.additionalAttributes,
});

const contactData = ref(getInitialContactData());

const isFormInvalid = computed(() => contactsFormRef.value?.isFormInvalid);

const countriesMap = computed(() => {
  return countries.reduce((acc, country) => {
    acc[country.code] = country;
    acc[country.id] = country;
    return acc;
  }, {});
});

const countryDetails = computed(() => {
  const attributes = props.additionalAttributes || {};
  const { country, countryCode, city } = attributes;

  if (!country && !countryCode) return null;

  const activeCountry =
    countriesMap.value[country] || countriesMap.value[countryCode];

  if (!activeCountry) return null;

  return {
    countryCode: activeCountry.id,
    city: city ? `${city},` : null,
    name: activeCountry.name,
  };
});

const formattedLocation = computed(() => {
  if (!countryDetails.value) return '';

  return [countryDetails.value.city, countryDetails.value.name]
    .filter(Boolean)
    .join(' ');
});

const handleFormUpdate = updatedData => {
  Object.assign(contactData.value, updatedData);
};

const handleUpdateContact = () => {
  emit('updateContact', contactData.value);
};

const onClickExpand = () => {
  emit('toggle');
  contactData.value = getInitialContactData();
};

const onClickViewDetails = () => emit('showContact', props.id);

const closePopup = () => {
  popupUrl.value = null;
};

function toLocalPhoneNumber(phone) {
  // Nếu bắt đầu bằng +84 thì thay bằng 0
  if (phone.startsWith('+84')) {
    return '0' + phone.slice(3);
  }
  return phone;
}

const handlePhoneIconClick = async () => {
  try {
    const { phoneNumber } = contactData.value;
    if (!phoneNumber) return;

    const response = await createJwtToken("36391_100");

    if (response && response.data && response.data.token) {
      const { token } = response.data;
      await login3C(null, token);

      // Chuyển số điện thoại sang dạng nội địa
      const localPhone = toLocalPhoneNumber(phoneNumber);
      const domain = "0938828282"; // hoặc lấy domain động nếu cần
      popupUrl.value = `https://3c-capi.mobifone.vn/${domain}/c2call?token=${token}&number=${localPhone}`;
    } else {
      console.error('Failed to create JWT token');
    }

  } catch (error) {
    console.error(error);
  }
};

watch(popupUrl, async (val) => {
  if (val) {
    try {
      // Kiểm tra quyền micro
      const permission = await navigator.permissions.query({ name: 'microphone' });
      if (permission.state !== 'granted') {
        // Yêu cầu quyền nếu chưa có
        await navigator.mediaDevices.getUserMedia({ audio: true });
      }
      // Nếu đã granted thì không cần làm gì
    } catch (err) {
      // Có thể xử lý lỗi hoặc thông báo cho người dùng
      console.error('Microphone permission denied or error:', err);
    }
  }
});

</script>

<template>
  <CardLayout :key="id" layout="row">
    <div class="flex items-center justify-start flex-1 gap-4">
      <Avatar :name="name" :src="thumbnail" :size="48" rounded-full />
      <div class="flex flex-col gap-0.5 flex-1">
        <div class="flex flex-wrap items-center gap-x-4 gap-y-1">
          <span class="text-base font-medium truncate text-n-slate-12">
            {{ name }}
          </span>
          <span class="inline-flex items-center gap-1">
            <span
              v-if="additionalAttributes?.companyName"
              class="i-ph-building-light size-4 text-n-slate-10 mb-0.5"
            />
            <span
              v-if="additionalAttributes?.companyName"
              class="text-sm truncate text-n-slate-11"
            >
              {{ additionalAttributes.companyName }}
            </span>
          </span>
        </div>
        <div class="flex flex-wrap items-center justify-start gap-x-3 gap-y-1">
          <div v-if="email" class="truncate max-w-72" :title="email">
            <span class="text-sm text-n-slate-11">
              {{ email }}
            </span>
          </div>
          <div v-if="email" class="w-px h-3 truncate bg-n-slate-6" />
          <span v-if="phoneNumber" class="text-sm truncate text-n-slate-11 flex items-center">
            <button
              type="button"
              class="ml-1 px-2 py-1 rounded hover:bg-n-slate-3 transition flex items-center justify-center gap-1"
              @click="handlePhoneIconClick"
              title="Call 3C"
            >
              <Icon icon="i-lucide-phone" class="inline-block text-n-slate-10 size-4 align-middle" />
              <span>{{ phoneNumber }}</span>
            </button>
          </span>
          <div v-if="phoneNumber" class="w-px h-3 truncate bg-n-slate-6" />
          <span
            v-if="countryDetails"
            class="inline-flex items-center gap-2 text-sm truncate text-n-slate-11"
          >
            <Flag :country="countryDetails.countryCode" class="size-3.5" />
            {{ formattedLocation }}
          </span>
          <div v-if="countryDetails" class="w-px h-3 truncate bg-n-slate-6" />
          <Button
            :label="t('CONTACTS_LAYOUT.CARD.VIEW_DETAILS')"
            variant="link"
            size="xs"
            @click="onClickViewDetails"
          />
        </div>
      </div>
    </div>

    <Button
      icon="i-lucide-chevron-down"
      variant="ghost"
      color="slate"
      size="xs"
      :class="{ 'rotate-180': isExpanded }"
      @click="onClickExpand"
    />

    <template #after>
      <transition
        enter-active-class="overflow-hidden transition-all duration-300 ease-out"
        leave-active-class="overflow-hidden transition-all duration-300 ease-in"
        enter-from-class="overflow-hidden opacity-0 max-h-0"
        enter-to-class="opacity-100 max-h-[690px] sm:max-h-[470px] md:max-h-[410px]"
        leave-from-class="opacity-100 max-h-[690px] sm:max-h-[470px] md:max-h-[410px]"
        leave-to-class="overflow-hidden opacity-0 max-h-0"
      >
        <div v-show="isExpanded" class="w-full">
          <div class="flex flex-col gap-6 p-6 border-t border-n-strong">
            <ContactsForm
              ref="contactsFormRef"
              :contact-data="contactData"
              @update="handleFormUpdate"
            />
            <div>
              <Button
                :label="
                  t('CONTACTS_LAYOUT.CARD.EDIT_DETAILS_FORM.UPDATE_BUTTON')
                "
                size="sm"
                :is-loading="isUpdating"
                :disabled="isUpdating || isFormInvalid"
                @click="handleUpdateContact"
              />
            </div>
          </div>
        </div>
      </transition>
    </template>
  </CardLayout>
  <div
    v-if="popupUrl"
    class="fixed inset-0 z-50 flex items-center justify-center bg-black bg-opacity-40"
  >
    <div class="bg-white rounded shadow-lg p-4 w-[90vw] max-w-2xl relative">
      <button
        class="absolute top-2 right-2 text-gray-500 hover:text-black"
        @click="closePopup"
        aria-label="Close"
      >
        ×
      </button>
      <div class="mb-2 font-semibold">Access 3C Call</div>
      <iframe
        :src="popupUrl"
        class="w-full h-[60vh] border rounded"
        frameborder="0"
        allow="microphone"
      ></iframe>
    </div>
  </div>
</template>
