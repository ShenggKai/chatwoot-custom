import axios from 'axios';

const DEFAULT_DOMAIN_3C = '0938828282';

export const createJwtToken = (ipphone) => {
  return axios.post('/api/v1/jwt_token', {
    'ipphone': ipphone,
  });
};

export const login3C = (domain, token) => {
  const usedDomain = domain || DEFAULT_DOMAIN_3C;

  return axios.post(
    `https://3c-capi.mobifone.vn/${usedDomain}/thirdParty/login`,
    { token },
    {
      headers: {
        'Content-Type': 'application/json',
      },
    }
  );
};